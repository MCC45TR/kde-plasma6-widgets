import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
        anchors.margins: Plasmoid.configuration.edgeMargin !== undefined ? Plasmoid.configuration.edgeMargin : 10
        // Use configured opacity
        opacity: (Plasmoid.configuration.backgroundOpacity !== undefined) ? Plasmoid.configuration.backgroundOpacity : 1.0
    }

    // Clock Face Container (Fills the widget)
    Item {
        id: clockFace
        anchors.fill: parent
        anchors.margins: Plasmoid.configuration.edgeMargin !== undefined ? Plasmoid.configuration.edgeMargin : 10 // Match background margins

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
            onEntered: clockFace.hoverState = true
            onExited: clockFace.hoverState = false
        }
        
        property bool hoverState: false
        property int style: Plasmoid.configuration.clockStyle !== undefined ? Plasmoid.configuration.clockStyle : 0 // 0=Auto, 1=Classic, 2=Modern
        
        // Classic (1) -> Always show detailed face (isHovered = true)
        // Modern (2) -> Never show detailed face (isHovered = false)
        // Auto (0) -> Show on hover
        
        property bool isHovered: style === 1 ? true : (style === 2 ? false : hoverState)
        
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
                    
                    property bool isCurrentHour: (index === (root.currentTime.getHours() % 12))
                    
                    font.family: numberFont.name
                    font.pixelSize: 16
                    color: Kirigami.Theme.textColor
                    
                    font.variableAxes: {
                        "wdth": isCurrentHour ? 151 : 100,
                        "wght": isCurrentHour ? 1000 : 500
                    }
                }
            }
        }


        // Hour Hand
        Item {
            id: hourHand
            z: 10 // Above digital clock
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
            z: 10 // Above digital clock
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

        // Digital Clock
        Item {
            id: digitalClock
            z: 0 // Below hands
            anchors.centerIn: parent
            width: parent.width * 0.6 // Approximate inner area
            height: parent.height * 0.6
            
            // Configuration
            property int style: Plasmoid.configuration.clockStyle !== undefined ? Plasmoid.configuration.clockStyle : 0 // 0=Auto, 1=Classic, 2=Modern
            
            // Logic for Small Square (Only Hour)
            // Ratio approx 1.0 (between 0.9 and 1.1) AND width is small (< 180)
            property bool isSmallSquare: (root.width / root.height > 0.9 && root.width / root.height < 1.1) && (root.width < 180)
            
            // Show condition: 
            // 1. Config says showDigitalClock is TRUE
            // 2. AND we are NOT in Classic Mode (Style 1 forces analog-only look usually, but let's respect the digital clock toggle too)
            //    Actually, let's say Classic Mode HIDES the central digital clock generally to look like a real clock.
            //    Unless user explicitly wants it. Let's keep existing logic: showDigitalClock controls it.
            //    BUT, if style is Classic, we might prefer hiding it. 
            //    Let's stick to the toggle: if 'showDigitalClock' is true, we show it.
            
            property bool show: (Plasmoid.configuration.showDigitalClock !== undefined ? Plasmoid.configuration.showDigitalClock : true) && (style !== 1)
            
            visible: show
            
            // Interaction Logic: Hide when hovered (switching to detailed analog mode), UNLESS style is modern?
            // If Style is Classic (1), we are always in "detailed analog mode" so digital is hidden anyway (logic above).
            // If Style is Modern (2), we likely want digital clock to persist even on hover? Or maybe not.
            // Let's keep the boolean isHovered logic for standard Auto mode.
            
            readonly property bool isHovered: clockFace.isHovered
            
            opacity: (show && !isHovered) ? 1.0 : 0.0
            scale: (show && !isHovered) ? 1.0 : 0.0
            
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            
            // Layout Logic: Vertical if height is > 10% larger than width
            property bool isVertical: root.height > (root.width * 1.1)
            
            // Time Components
            property string hourText: Qt.formatTime(root.currentTime, "HH")
            property string minText: Qt.formatTime(root.currentTime, "mm")
            
            // Font Settings
            property bool useCustom: Plasmoid.configuration.useCustomFont || false
            property string customFamily: Plasmoid.configuration.customFontFamily || ""
            property string effectiveFont: useCustom && customFamily ? customFamily : numberFont.name

            // Global Digital Clock Config
            property bool fontAutoAdjust: Plasmoid.configuration.fontAutoAdjust !== undefined ? Plasmoid.configuration.fontAutoAdjust : true
            property int fixedWeight: Plasmoid.configuration.fixedWeight !== undefined ? Plasmoid.configuration.fixedWeight : 400
            property int fixedWidth: Plasmoid.configuration.fixedWidth !== undefined ? Plasmoid.configuration.fixedWidth : 100
            
            // Vertical Spacing (percentage: 10 means 0.1)
            property real verticalSpacing: (Plasmoid.configuration.verticalSpacingRatio !== undefined ? Plasmoid.configuration.verticalSpacingRatio : 10) / 100.0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: digitalClock.height * digitalClock.verticalSpacing // Dynamic spacing from config
                visible: digitalClock.isVertical
                
                // Vertical Layout Text
                Text {
                    text: digitalClock.hourText
                    font.family: digitalClock.effectiveFont
                    
                    // Dynamic Font Fitting for Vertical Mode
                    property real fitHeight: digitalClock.height * 0.45
                    
                    font.pixelSize: fitHeight
                    
                    // Auto Logic: Vertical mode always most condensed (wdth 25), weight 400
                    property int autoWdth: 25
                    property int autoWght: 400
                    
                    font.variableAxes: {
                        "wdth": digitalClock.fontAutoAdjust ? autoWdth : digitalClock.fixedWidth,
                        "wght": digitalClock.fontAutoAdjust ? autoWght : digitalClock.fixedWeight
                    }
                    
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: digitalClock.minText
                    font.family: digitalClock.effectiveFont
                    
                    property real fitHeight: digitalClock.height * 0.45
                    font.pixelSize: fitHeight
                    
                    property int autoWdth: 25
                    property int autoWght: 400
                    
                    font.variableAxes: {
                        "wdth": digitalClock.fontAutoAdjust ? autoWdth : digitalClock.fixedWidth,
                        "wght": digitalClock.fontAutoAdjust ? autoWght : digitalClock.fixedWeight
                    }
                    
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignHCenter
                }
            }
            
            // Horizontal Layout (Standard)
            Text {
                anchors.centerIn: parent
                visible: !digitalClock.isVertical && !digitalClock.isSmallSquare
                text: digitalClock.hourText + ":" + digitalClock.minText
                font.family: digitalClock.effectiveFont
                
                // Horizontal Fitting
                // 5 chars (HH:MM) approx 3.0em width
                property real maxH: parent.height * 0.6
                property real maxW: parent.width
                
                // Base pixel size on height first
                font.pixelSize: maxH
                
                // Calculate width compression needed
                // 5 chars * 0.6 = 3.0 aspect
                property real requiredWdth: (maxW / (maxH * 2.8)) * 100
                property real clampedWdth: Math.min(151, Math.max(25, requiredWdth))
                
                // Keep weight dynamic in horizontal mode for best fit
                property real autoWeight: Math.min(1000, Math.max(100, clampedWdth * 5))
                property int autoWidth: clampedWdth
                
                font.variableAxes: {
                    "wdth": digitalClock.fontAutoAdjust ? autoWidth : digitalClock.fixedWidth,
                    "wght": digitalClock.fontAutoAdjust ? autoWeight : digitalClock.fixedWeight
                }

                color: Kirigami.Theme.textColor
            }
            
            // Small Square Layout (ONLY HOUR)
            Text {
                anchors.centerIn: parent
                visible: !digitalClock.isVertical && digitalClock.isSmallSquare
                text: digitalClock.hourText
                font.family: digitalClock.effectiveFont

                // Max out available space
                property real maxH: parent.height * 0.85
                property real maxW: parent.width * 0.85
                
                font.pixelSize: maxH
                
                // 2 chars (HH) approx 1.2 aspect
                property real requiredWdth: (maxW / (maxH * 1.2)) * 100
                property real clampedWdth: Math.min(151, Math.max(25, requiredWdth))
                
                // Auto Logic: Prefer bold/wide for single hour
                property int autoWdth: clampedWdth
                property int autoWght: 800
                
                font.variableAxes: {
                    "wdth": digitalClock.fontAutoAdjust ? autoWdth : digitalClock.fixedWidth,
                    "wght": digitalClock.fontAutoAdjust ? autoWght : digitalClock.fixedWeight
                }

                color: Kirigami.Theme.textColor
            }
        }
    }
}
