import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// SeekBar.qml - Paylaşılan seek bar bileşeni
MouseArea {
    id: seekBar
    
    // Required properties
    required property real currentPosition
    required property real length
    required property var onSeek // Function(micros)
    
    // Optional styling
    property real barHeight: 6
    property real thumbSize: 14
    property bool showThumb: true
    property color trackColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
    property color progressColor: Kirigami.Theme.highlightColor
    
    // Internal state
    property bool dragging: false
    
    height: Math.max(barHeight + 10, thumbSize)
    
    onPressed: dragging = true
    onReleased: {
        dragging = false
        if (length > 0) {
            onSeek((mouseX / width) * length)
        }
    }
    
    // Background track
    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: seekBar.barHeight
        radius: height / 2
        color: seekBar.trackColor
    }
    
    // Progress track
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: seekBar.barHeight
        radius: height / 2
        color: seekBar.progressColor
        width: {
            if (seekBar.length <= 0) return 0
            var pos = seekBar.dragging ? (seekBar.mouseX / seekBar.width) * seekBar.length : seekBar.currentPosition
            return Math.max(0, Math.min(parent.width, (pos / seekBar.length) * parent.width))
        }
    }
    
    // Thumb
    Rectangle {
        visible: seekBar.showThumb
        width: seekBar.thumbSize
        height: seekBar.thumbSize
        radius: width / 2
        color: seekBar.progressColor
        anchors.verticalCenter: parent.verticalCenter
        x: {
            if (seekBar.length <= 0) return -width / 2
            var pos = seekBar.dragging ? (seekBar.mouseX / seekBar.width) * seekBar.length : seekBar.currentPosition
            return (parent.width * (pos / seekBar.length)) - width / 2
        }
    }
}
