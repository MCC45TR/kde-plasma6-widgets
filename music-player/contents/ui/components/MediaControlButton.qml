import QtQuick
import org.kde.kirigami as Kirigami

// MediaControlButton.qml - Animasyonlu media kontrol butonu
Item {
    id: controlBtn
    
    // Required properties
    required property string iconSource
    required property var onClicked
    
    // Optional properties
    property real baseSize: 36
    property real expandAmount: 20
    property real iconScale: 0.6
    property string anchorMode: "center" // "left", "center", "right"
    property color bgColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
    
    // External press states for group animation
    property bool pressed: false
    property real shrinkAmount: 0
    
    width: baseSize + (pressed ? expandAmount : 0) - shrinkAmount
    height: baseSize
    
    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    
    Rectangle {
        id: bgRect
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width
        radius: 5
        color: controlBtn.bgColor
        
        states: [
            State {
                name: "left"
                when: controlBtn.anchorMode === "left"
                AnchorChanges { target: bgRect; anchors.left: parent.left; anchors.right: undefined; anchors.horizontalCenter: undefined }
            },
            State {
                name: "center"
                when: controlBtn.anchorMode === "center"
                AnchorChanges { target: bgRect; anchors.left: undefined; anchors.right: undefined; anchors.horizontalCenter: parent.horizontalCenter }
            },
            State {
                name: "right"
                when: controlBtn.anchorMode === "right"
                AnchorChanges { target: bgRect; anchors.left: undefined; anchors.right: parent.right; anchors.horizontalCenter: undefined }
            }
        ]
    }
    
    Kirigami.Icon {
        anchors.centerIn: parent
        source: controlBtn.iconSource
        width: controlBtn.baseSize * controlBtn.iconScale
        height: width
        color: Kirigami.Theme.textColor
        opacity: 0.9
    }
    
    MouseArea {
        anchors.fill: parent
        onPressed: controlBtn.pressed = true
        onReleased: {
            controlBtn.pressed = false
            controlBtn.onClicked()
        }
        onCanceled: controlBtn.pressed = false
    }
}
