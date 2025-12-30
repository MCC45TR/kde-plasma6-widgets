import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    // Widget preferences
    // Disable the default translucent background from Plasma
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Layout.preferredWidth: 200
    Layout.preferredHeight: 200
    Layout.minimumWidth: 170
    Layout.minimumHeight: 170
    Layout.maximumWidth: 250
    Layout.maximumHeight: 250

    property var currentTime: new Date()
    function updateTime() {
        root.currentTime = new Date()
    }
    
    // Updated 24.12.27: Math for Squircle/Rounded Rectangle
    property real cornerRadius: Math.min(width, height) * 0.11

    // Function to calculate intersection distance from center to Rounded Rectangle edge
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
        
        // Vertical hit check (x = +/- w2)
        var tVert = w2 / sinT
        var yVert = tVert * cosT
        if (yVert <= ih) return tVert
        
        // Horizontal hit check (y = +/- h2)
        var tHorz = h2 / cosT
        var xHorz = tHorz * sinT
        if (xHorz <= iw) return tHorz
        
        // Corner intersection
        var B = 2 * (-iw * sinT - ih * cosT)
        var C = (iw * iw + ih * ih) - r * r
        
        var det = B*B - 4*C
        if (det < 0) return Math.min(tVert, tHorz) 
        
        return (-B + Math.sqrt(det)) / 2
    }

    // Function to warp circular angles to rectangular aspect ratio
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

    Timer {
        interval: 100
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateTime()
    }

    FontLoader {
        id: numberFont
        source: "../fonts/RobotoFlex.ttf"
    }

    // Main Background
    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        radius: 20
        opacity: 1
        anchors.margins: 10
    }

    // Clock Face Container (Fills the widget)
    Item {
        id: clockFace
        anchors.fill: parent
        anchors.margins: 10 // Match background margins

        // Center Point (Pivot)

        Item {
            id: centerPivot
            anchors.centerIn: parent
            width: 1
            height: 1
            z: 10
        }

        // Handy property for consistent thickness
        readonly property real baseThick: 15
        readonly property real secondThick: 3 // Fixed thin size for second hand
        readonly property real handOffset: Math.min(width, height) * 0.15
        readonly property real hourHandStartOffset: Math.min(width, height) * 0.2
        readonly property real edgeMargin: Math.min(width, height) * 0.08
        readonly property real tickInset: 15
        readonly property real hoverCenterGap: Math.min(width, height) * 0.1
        
        // Mouse Interaction for Hover Effect
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: clockFace.isHovered = true
            onExited: clockFace.isHovered = false
        }
        
        property bool isHovered: false
        
        // Radius for the circular arrangement of numbers
        readonly property real numberRadius: (Math.min(clockFace.width, clockFace.height) - 20) / 2 - 20

        // 60 Ticks Geometry
        
        // Background Circle for Numbers (Visible on Hover)
        Rectangle {
            anchors.centerIn: parent
            // Diameter: Enough to encompass the numbers placed at 0.35 * dimension
            // 0.35 radius means 0.7 diameter + text size + padding => ~0.85
            width: Math.min(parent.width, parent.height) - 20
            height: width
            radius: width / 2
            color: Kirigami.Theme.textColor
            opacity: clockFace.isHovered ? 0.05 : 0 // 5% opacity when hovered
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Repeater {
            model: 60
            Item {
                id: tickItem
                visible: opacity > 0
                opacity: clockFace.isHovered ? 0 : 1
                
                Behavior on opacity { NumberAnimation { duration: 200 } }

                // Index 0 is 12 o'clock, 15 is 3 o'clock, etc.
                // Warp the angle based on aspect ratio
                readonly property real angleDeg: root.getProjectedAngle(index * 6)
                
                // Calculate position considering the shape
                // We use calculateRayLength to get distance to edge, then padding
                readonly property real dist: root.calculateRayLength(angleDeg) 
                
                x: clockFace.width/2 + Math.sin(angleDeg * Math.PI / 180) * dist - width/2
                y: clockFace.height/2 - Math.cos(angleDeg * Math.PI / 180) * dist - height/2
                
                width: 4
                height: 4 
                
                // Visual Tick (Rectangle)
                Rectangle {
                   anchors.centerIn: parent
                   // Dynamic Tick Size: thicker at cardinal points (0, 15, 30, 45)
                   width: (index % 5 === 0) ? 4 : 2
                   // Length constant as requested
                   height: 15
                   
                   rotation: tickItem.angleDeg
                   
                   // Color Logic: Lit up if passed. 
                   // Note: 'index' corresponds to time-seconds.
                   color: index <= root.currentTime.getSeconds() ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                   
                   Behavior on color {
                       ColorAnimation { duration: 150 }
                   }

                   radius: width / 2
                   antialiasing: true
                }
            }
        }

        // Hour Numbers (Visible on Hover)
        Repeater {
            model: 12
            Item {
                id: numberItem
                visible: opacity > 0
                opacity: clockFace.isHovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                // 12 hours -> 30 degrees each (Standard Circle)
                readonly property real angleDeg: index * 30
                // Circular distance (radius)
                readonly property real dist: (Math.min(clockFace.width, clockFace.height) - 20) / 2 - 20 //Radius is half diameter, minus margin for text centering 
                
                // Centered at the tick position
                x: clockFace.width/2 + Math.sin(angleDeg * Math.PI / 180) * dist - width/2
                y: clockFace.height/2 - Math.cos(angleDeg * Math.PI / 180) * dist - height/2
                
                width: 30
                height: 30
                
                Text {
                    anchors.centerIn: parent
                    
                    text: {
                        var h = index === 0 ? 12 : index
                        // Check AM/PM context
                        var hour = root.currentTime.getHours()
                        
                        if (hour >= 12) {
                            // PM Mode: 12..23
                            if (h === 12) return "12"
                            return (h + 12).toString()
                        } else {
                            // AM Mode: 0..11 (Display 12..11)
                            // 00:xx is displayed as 12
                            return h.toString()
                        }
                    }
                    
                    font.family: numberFont.name
                    font.bold: true
                    font.pixelSize: 16
                    color: Kirigami.Theme.textColor
                    
                    // Small rotation to match the face curve?
                    // rotation: numberItem.angleDeg 
                    // Let's NOT rotate text for now.
                }
            }
        }


        // Hour Hand
        Item {
            id: hourHand
            width: clockFace.isHovered ? clockFace.secondThick : 10
            Behavior on width { NumberAnimation { duration: 300 } }
            
            readonly property real rawAngle: (root.currentTime.getHours() * 30) + (root.currentTime.getMinutes() * 0.5) + (root.currentTime.getSeconds() * 0.008333)
            readonly property real projAngle: root.getProjectedAngle(rawAngle)
            
            rotation: clockFace.isHovered ? rawAngle : projAngle
            Behavior on rotation { RotationAnimation { direction: RotationAnimation.Shortest; duration: 300 } }
            
            readonly property real sqHeight: calculateRayLength(projAngle)
            height: clockFace.isHovered ? clockFace.numberRadius : sqHeight
            Behavior on height { NumberAnimation { duration: 300 } }
            
            anchors.bottom: centerPivot.verticalCenter
            anchors.horizontalCenter: centerPivot.horizontalCenter
            transformOrigin: Item.Bottom

            Rectangle {
                width: parent.width
                // Extend hand to center when hovered (Full Radius)
                height: clockFace.isHovered ? parent.height * 0.75 : clockFace.handOffset
                Behavior on height { NumberAnimation { duration: 300 } }
                
                anchors.top: parent.top
                anchors.topMargin: clockFace.isHovered ? parent.height * 0.25 : clockFace.edgeMargin
                Behavior on anchors.topMargin { NumberAnimation { duration: 300 } }

                anchors.horizontalCenter: parent.horizontalCenter
                
                color: Kirigami.Theme.textColor
                opacity: clockFace.isHovered ? 1 : 0.8
                radius: width / 2
                antialiasing: true
            }
        }

        // Minute Hand
        Item {
            id: minuteHand
            // Width Logic: Use hourHand width (10) when hovered, otherwise 3
            width: clockFace.isHovered ? hourHand.width : 3
            Behavior on width { NumberAnimation { duration: 300 } }
            
            readonly property real rawAngle: (root.currentTime.getMinutes() * 6) + (root.currentTime.getSeconds() * 0.1) + (root.currentTime.getMilliseconds() * 0.0001)
            readonly property real projAngle: root.getProjectedAngle(rawAngle)
            
            rotation: clockFace.isHovered ? rawAngle : projAngle
            Behavior on rotation { RotationAnimation { direction: RotationAnimation.Shortest; duration: 300 } }
            
            readonly property real sqHeight: calculateRayLength(projAngle)
            height: clockFace.isHovered ? clockFace.numberRadius : sqHeight
            Behavior on height { NumberAnimation { duration: 300 } }
            
            anchors.bottom: centerPivot.verticalCenter
            anchors.horizontalCenter: centerPivot.horizontalCenter
            transformOrigin: Item.Bottom

            Rectangle {
                width: parent.width
                // Extend hand to center when hovered (Full Radius)
                height: clockFace.isHovered ? parent.height : clockFace.handOffset
                Behavior on height { NumberAnimation { duration: 300 } }
                
                // Position logic
                anchors.top: parent.top
                anchors.topMargin: clockFace.isHovered ? 0 : clockFace.edgeMargin
                Behavior on anchors.topMargin { NumberAnimation { duration: 300 } }
                
                anchors.horizontalCenter: parent.horizontalCenter
                
                color: Kirigami.Theme.textColor
                opacity: clockFace.isHovered ? 1 : 0.8
                radius: width / 2
                antialiasing: true
            }
        }
        
        // Second Hand (Visible only in Circular Mode / Hover)
        Item {
            id: secondHand
            z: 50 // On top of everything
            width: clockFace.secondThick
            
            property real angle: (root.currentTime.getSeconds() * 6) + (root.currentTime.getMilliseconds() * 0.006)
            rotation: angle
            
            // Fixed height to reach the numbers without animation
            height: clockFace.numberRadius
            
            anchors.bottom: centerPivot.verticalCenter
            anchors.horizontalCenter: centerPivot.horizontalCenter
            transformOrigin: Item.Bottom
            
            opacity: clockFace.isHovered ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            
            Rectangle {
                anchors.fill: parent
                radius: width/2
                color: Kirigami.Theme.highlightColor
                opacity: 0.8
            }
        }

        // Center Dot (Visible only in Circular Mode / Hover)
        Rectangle {
            id: centerDot
            z: 100 // Topmost layer
            anchors.centerIn: parent
            
            // Diameter 22.5 (3/4 of 30), grows from 0
            width: clockFace.isHovered ? 11 : 0
            height: width
            radius: width / 2
            
            color: Kirigami.Theme.textColor
            
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
    }
}
