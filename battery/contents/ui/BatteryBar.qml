import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property int percentage: 0
    property bool isCharging: false
    property string label: ""
    property string iconName: ""
    property bool showLabel: true
    property string remainingTime: "" // e.g., "Remaining to 20:45"
    
    // Configurable specific color or default logic
    // Requirements: < 25% Yellow, < 15% Red, else System Accent
    readonly property color barColor: {
        if (percentage < 15) return Kirigami.Theme.negativeColor // Redish
        if (percentage < 25) return Kirigami.Theme.neutralColor // Yellowish/Orange
        return Kirigami.Theme.highlightColor // System Accent
    }

    readonly property color trackColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
    
    // Animation for low battery (<15%)
    // "progress bars ... blink animation 1.0 to 0.5 opacity, 200ms duration, 3s wait"
    // Since we apply this to the bar itself
    property real barOpacity: 1.0
    
    SequentialAnimation {
        running: percentage < 15 && !isCharging
        loops: Animation.Infinite
        
        NumberAnimation { target: root; property: "barOpacity"; from: 1.0; to: 0.5; duration: 200 }
        NumberAnimation { target: root; property: "barOpacity"; from: 0.5; to: 1.0; duration: 200 }
        PauseAnimation { duration: 3000 }
    }
    
    // Reset opacity if not running
    onPercentageChanged: {
        if (percentage >= 15) barOpacity = 1.0
    }

    // Layout
    // We need to support vertical (Large/Small?) and horizontal (Broad) usage? 
    // The visual provided shows:
    // Broad Mode: Horizontal Bars? No, Broad mode image shows vertical bars next to each other? 
    // Wait, let's look at the images again.
    // Image 1: Square, big percentage text, big icon.
    // Image 2: Wide/Broad. Vertical bars on the left, Main info on right.
    // Image 3: Large (Tall?). Vertical bars.
    
    // It seems the "Bar" itself is a vertical column or horizontal row depending on context?
    // Actually, looking at "Wide" (Image 2): It has 3 vertical bars + Main Text.
    // Looking at "Large" (Image 3): It has 3 vertical bars (very tall).
    
    // So distinct feature: the battery bar is a vertical fill bar.
    
    property real radiusTopLeft: 4
    property real radiusTopRight: 4
    property real radiusBottomLeft: 4
    property real radiusBottomRight: 4

    // Mask Shape
    Shape {
        id: maskShape
        anchors.fill: parent
        visible: false
        preferredRendererType: Shape.CurveRenderer // Smooth edges
        
        ShapePath {
            strokeWidth: 0
            fillColor: "black" // Opaque for mask
            
            PathRectangle {
                x: 0; y: 0
                width: maskShape.width
                height: maskShape.height
                topLeftRadius: root.radiusTopLeft
                topRightRadius: root.radiusTopRight
                bottomLeftRadius: root.radiusBottomLeft
                bottomRightRadius: root.radiusBottomRight
            }
        }
    }

    // Content container masked by shape
    Item {
        id: container
        anchors.fill: parent
        
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: maskShape
        }
        
        // Track Background
        Rectangle {
            anchors.fill: parent
            color: root.trackColor
        }
        
        // Fill Bar
        Rectangle {
            id: fill
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * (root.percentage / 100)
            color: root.barColor
            opacity: root.barOpacity
            
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        
        // Icon
        Kirigami.Icon {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 8
            width: parent.width * 0.6
            height: width
            source: root.iconName
            
            // Monochrome Logic
            property color monoColor: {
                if (root.percentage <= 10) return Kirigami.Theme.textColor
                // Yellow range (15-25 typically, but here <25 is yellow, <15 is red)
                if (root.percentage >= 15 && root.percentage < 25) return "black"
                return "white"
            }
            color: monoColor
        }
    }
    
    // Text overlay is handled by parent if needed.
}
