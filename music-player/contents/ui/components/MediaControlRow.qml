import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// MediaControlRow.qml - Prev/Play/Next buton grubu
RowLayout {
    id: controlsRow
    
    // Properties (with defaults for Loader compatibility)
    property bool isPlaying: false
    property var onPrevious: function() {}
    property var onPlayPause: function() {}
    property var onNext: function() {}
    
    // Optional properties
    property real baseSize: 36
    property real expandAmount: 20
    property real iconScale: 0.6
    property color bgColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
    
    // Internal state
    property bool prevPressed: false
    property bool playPressed: false
    property bool nextPressed: false
    
    spacing: 4
    
    // Previous Button
    Item {
        Layout.preferredWidth: controlsRow.baseSize + (controlsRow.prevPressed ? controlsRow.expandAmount : 0) - (controlsRow.playPressed ? controlsRow.expandAmount / 2 : 0)
        Layout.preferredHeight: controlsRow.baseSize
        
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width
            radius: 5
            color: controlsRow.bgColor
        }
        
        Kirigami.Icon {
            anchors.centerIn: parent
            source: "media-skip-backward"
            width: controlsRow.baseSize * controlsRow.iconScale
            height: width
            color: Kirigami.Theme.textColor
            opacity: 0.9
        }
        
        MouseArea {
            anchors.fill: parent
            onPressed: controlsRow.prevPressed = true
            onReleased: { controlsRow.prevPressed = false; controlsRow.onPrevious() }
            onCanceled: controlsRow.prevPressed = false
        }
    }
    
    // Play/Pause Button
    Item {
        Layout.preferredWidth: controlsRow.baseSize + (controlsRow.playPressed ? controlsRow.expandAmount : 0) - (controlsRow.prevPressed ? controlsRow.expandAmount / 2 : 0) - (controlsRow.nextPressed ? controlsRow.expandAmount / 2 : 0)
        Layout.preferredHeight: controlsRow.baseSize
        
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width
            radius: 5
            color: controlsRow.bgColor
        }
        
        Kirigami.Icon {
            anchors.centerIn: parent
            source: controlsRow.isPlaying ? "media-playback-pause" : "media-playback-start"
            width: controlsRow.baseSize * controlsRow.iconScale
            height: width
            color: Kirigami.Theme.textColor
            opacity: 0.9
        }
        
        MouseArea {
            anchors.fill: parent
            onPressed: controlsRow.playPressed = true
            onReleased: { controlsRow.playPressed = false; controlsRow.onPlayPause() }
            onCanceled: controlsRow.playPressed = false
        }
    }
    
    // Next Button
    Item {
        Layout.preferredWidth: controlsRow.baseSize + (controlsRow.nextPressed ? controlsRow.expandAmount : 0) - (controlsRow.playPressed ? controlsRow.expandAmount / 2 : 0)
        Layout.preferredHeight: controlsRow.baseSize
        
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width
            radius: 5
            color: controlsRow.bgColor
        }
        
        Kirigami.Icon {
            anchors.centerIn: parent
            source: "media-skip-forward"
            width: controlsRow.baseSize * controlsRow.iconScale
            height: width
            color: Kirigami.Theme.textColor
            opacity: 0.9
        }
        
        MouseArea {
            anchors.fill: parent
            onPressed: controlsRow.nextPressed = true
            onReleased: { controlsRow.nextPressed = false; controlsRow.onNext() }
            onCanceled: controlsRow.nextPressed = false
        }
    }
}
