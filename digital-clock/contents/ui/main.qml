import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    
    // Disable default background
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Layout.preferredWidth: 200
    Layout.preferredHeight: 200
    Layout.minimumWidth: 170
    Layout.minimumHeight: 170
    Layout.maximumWidth: 250
    Layout.maximumHeight: 250
    
    // Hover State
    property bool isHovering: false
    
    // Wide Mode Trigger (Same as Music Player) - REMOVED
    // readonly property bool isLarge: (root.height > 350) && (root.width < root.height * 1.05)
    // readonly property bool isWide: !isLarge && (root.width > (root.height * 1.05))
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.isHovering = true
        onExited: root.isHovering = false
        // Let clicks pass through if needed, or handle them
        acceptedButtons: Qt.NoButton
    }
    
    // Time Logic
    property var currentTime: new Date()
    function updateTime() {
        root.currentTime = new Date()
    }
    
    FontLoader {
        id: clockFont
        source: "../fonts/RobotoCondensed-VariableFont_wght.ttf"
    }
    
    Timer {
        interval: 100
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateTime()
    }
    
    // Geometry for Squircle check (Reused from Analog Clock)
    property real cornerRadius: Math.min(width, height) * 0.11

    function calculateRayLength(angleInDegrees) {
        var offset = clockFace.tickInset
        var w = clockFace.width - 2 * offset
        var h = clockFace.height - 2 * offset
        var w2 = w / 2
        var h2 = h / 2
        var r = Math.max(0, root.cornerRadius - offset)
        
        var theta = angleInDegrees * Math.PI / 180
        var sinT = Math.abs(Math.sin(theta))
        var cosT = Math.abs(Math.cos(theta))
        if (sinT < 0.001) sinT = 0.001
        if (cosT < 0.001) cosT = 0.001
        
        var iw = w2 - r
        var ih = h2 - r
        var tVert = w2 / sinT
        var yVert = tVert * cosT
        if (yVert <= ih) return tVert
        var tHorz = h2 / cosT
        var xHorz = tHorz * sinT
        if (xHorz <= iw) return tHorz
        
        var B = 2 * (-iw * sinT - ih * cosT)
        var C = (iw * iw + ih * ih) - r * r
        var det = B*B - 4*C
        if (det < 0) return Math.min(tVert, tHorz) 
        return (-B + Math.sqrt(det)) / 2
    }

    function getProjectedAngle(angleInDegrees) {
        var theta = angleInDegrees * Math.PI / 180
        var x = Math.sin(theta)
        var y = -Math.cos(theta)
        x = x * clockFace.width
        y = y * clockFace.height
        var newTheta = Math.atan2(x, -y)
        var newDegree = newTheta * 180 / Math.PI
        if (newDegree < 0) newDegree += 360
        return newDegree
    }
    
    // Main Background
    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        radius: 20
        opacity: 1
        anchors.margins: 10
    }

    Item {
        id: clockFace
        anchors.fill: parent
        anchors.margins: 10

        // Configs
        readonly property real tickInset: 15
        
        // Ticks Repeater (Seconds)
        Repeater {
            model: 60
            Item {
                id: tickItem
                // Geometry logic reuse
                readonly property real angleDeg: root.getProjectedAngle(index * 6)
                readonly property real dist: root.calculateRayLength(angleDeg)
                
                x: clockFace.width/2 + Math.sin(angleDeg * Math.PI / 180) * dist - width/2
                y: clockFace.height/2 - Math.cos(angleDeg * Math.PI / 180) * dist - height/2
                
                width: 4
                height: 4
                
                Rectangle {
                   anchors.centerIn: parent
                   width: ((index % 5 === 0) ? 4 : 2) * (root.isWide ? 2 : 1)
                   height: root.isWide ? (clockFace.height * 0.06) : 15
                   // Hide ticks in wide mode (Actually show on hover per request, always in Large)
                   opacity: (root.isLarge || root.isHovering) ? 0.8 : 0
                   Behavior on opacity { NumberAnimation { duration: 300 } }
                   rotation: tickItem.angleDeg
                   
                   // Lit up if index <= seconds
                   color: index <= root.currentTime.getSeconds() ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                   
                   Behavior on color { ColorAnimation { duration: 150 } }
                   radius: width / 2
                   antialiasing: true
                }
            }
        }
        
        // Unified Time Display with States & Transitions
        Item {
            id: timeDisplay
            anchors.fill: parent
            
            readonly property string activeFontFamily: (Plasmoid.configuration.customFont !== "") ? Plasmoid.configuration.customFont : clockFont.name
            readonly property bool show24h: Plasmoid.configuration.use24HourFormat
            
            // Hour Text
            Text {
                id: hourText
                text: Qt.formatTime(root.currentTime, parent.show24h ? "HH" : "hh")
                font.family: parent.activeFontFamily
                font.weight: Font.Light
                color: Kirigami.Theme.textColor
                opacity: 0.7
                
                // Anchors and Size managed by State
                Behavior on font.pixelSize { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            }
            
            // Separator
            Text {
                id: sepText
                text: ":"
                font.family: parent.activeFontFamily
                font.weight: Font.Normal
                color: Kirigami.Theme.textColor
                
                // Breath Animation for WIDE mode only
                SequentialAnimation on opacity {
                    id: breathAnim
                    loops: Animation.Infinite
                    running: root.isWide
                    NumberAnimation { from: 1; to: 0.3; duration: 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.3; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
                }
            }
            
            // Minute Text
            Text {
                id: minText
                text: Qt.formatTime(root.currentTime, "mm")
                font.family: parent.activeFontFamily
                font.weight: Font.Normal
                color: Kirigami.Theme.textColor
                opacity: 0.8
                Behavior on font.pixelSize { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            }

            states: [
                State {
                    name: "compact"
                    when: !root.isWide && !root.isLarge
                    PropertyChanges { 
                        target: hourText
                        anchors.horizontalCenter: timeDisplay.horizontalCenter
                        anchors.bottom: timeDisplay.verticalCenter
                        anchors.bottomMargin: -clockFace.height * 0.05
                        anchors.left: undefined; anchors.right: undefined; anchors.top: undefined; anchors.verticalCenter: undefined
                        // Dynamic sizing based on Hover.
                        font.pixelSize: Math.min(clockFace.width, clockFace.height) * (root.isHovering ? 0.38 : 0.45)
                        horizontalAlignment: Text.AlignHCenter
                    }
                    PropertyChanges { 
                        target: minText
                        anchors.horizontalCenter: timeDisplay.horizontalCenter
                        anchors.top: timeDisplay.verticalCenter
                        anchors.topMargin: -clockFace.height * 0.05
                        anchors.left: undefined; anchors.right: undefined; anchors.bottom: undefined
                        // Dynamic sizing based on Hover.
                        font.pixelSize: Math.min(clockFace.width, clockFace.height) * (root.isHovering ? 0.38 : 0.45)
                        horizontalAlignment: Text.AlignHCenter
                    }
                    PropertyChanges { target: sepText; opacity: 0; font.pixelSize: 0 }
                },
                State {
                    name: "wide"
                    when: root.isWide
                     PropertyChanges { 
                        target: sepText
                        opacity: 1
                        anchors.centerIn: parent
                        anchors.right: undefined; anchors.bottom: undefined
                        font.pixelSize: clockFace.height * 0.8
                    }
                    PropertyChanges { 
                        target: hourText
                        anchors.right: sepText.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: undefined; anchors.bottom: undefined; anchors.left: undefined
                        font.pixelSize: clockFace.height * 0.8
                        horizontalAlignment: Text.AlignRight
                    }
                    PropertyChanges { 
                        target: minText
                        anchors.left: sepText.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: undefined; anchors.top: undefined; anchors.right: undefined
                        font.pixelSize: clockFace.height * 0.8
                        horizontalAlignment: Text.AlignLeft
                    }
                },
                State {
                    name: "large"
                    when: root.isLarge
                    PropertyChanges { 
                        target: hourText
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: undefined; anchors.bottom: undefined; anchors.right: undefined
                        font.pixelSize: clockFace.height * 0.85
                        horizontalAlignment: Text.AlignLeft
                    }
                    PropertyChanges { 
                        target: minText
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: clockFace.height * 0.15
                        anchors.horizontalCenter: undefined; anchors.left: undefined; anchors.verticalCenter: undefined
                        font.pixelSize: clockFace.height * 0.45
                        horizontalAlignment: Text.AlignRight
                    }
                    PropertyChanges { 
                        target: sepText
                        opacity: 1
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: clockFace.height * 0.18
                        anchors.centerIn: undefined
                        font.pixelSize: clockFace.height * 0.45
                    }
                }
            ]
            
            transitions: Transition {
                ParallelAnimation {
                    AnchorAnimation { duration: 500; easing.type: Easing.OutCubic }
                    NumberAnimation { properties: "font.pixelSize, opacity, anchors.margins"; duration: 500; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
