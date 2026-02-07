import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    // Required properties
    property string currentProfile: "balanced" // "power-saver", "balanced", "performance"
    property int radius: 10
    
    // Output signal
    signal profileChanged(string profile)
    
    // Internal
    readonly property var profiles: ["power-saver", "balanced", "performance"]
    readonly property int slotWidth: track.width / 3
    readonly property var snapPositions: [0, slotWidth, slotWidth * 2]
    
    // Internal state to prevent bounce-back
    property string internalProfile: currentProfile
    onCurrentProfileChanged: internalProfile = currentProfile
    
    // Track background
    Rectangle {
        id: track
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        radius: root.radius
        
        // Highlight indicator
        Rectangle {
            id: highlightRect
            width: root.slotWidth
            height: parent.height
            radius: root.radius
            color: Qt.rgba(1, 1, 1, 0.2)
            
            // Target position based on internal profile
            property real targetX: {
                switch(root.internalProfile) {
                    case "power-saver": return 0
                    case "balanced": return root.slotWidth
                    case "performance": return root.slotWidth * 2
                    default: return root.slotWidth
                }
            }
            
            // Smooth spring animation
            SpringAnimation {
                id: snapAnimation
                target: highlightRect
                property: "x"
                spring: 5
                damping: 0.4
                mass: 0.6
            }
            
            // Set initial position
            Component.onCompleted: x = targetX
            
            // Animate when target changes (but not during drag)
            onTargetXChanged: {
                if (!dragHandler.active && !snapAnimation.running) {
                    snapAnimation.to = targetX
                    snapAnimation.start()
                }
            }
        }
        
        // Icons layer
        RowLayout {
            anchors.fill: parent
            spacing: 0
            
            // Calculate which slot the highlight is currently over
            property int hoveredSlot: {
                var center = highlightRect.x + highlightRect.width / 2
                if (center < root.slotWidth) return 0
                if (center < root.slotWidth * 2) return 1
                return 2
            }
            
            Repeater {
                model: [
                    { icon: "battery-profile-powersave", profile: "power-saver", color: "#4CAF50", index: 0 },
                    { icon: "power-profile-balanced-symbolic", profile: "balanced", color: "#FFC107", index: 1 },
                    { icon: "battery-profile-performance", profile: "performance", color: "#FF5252", index: 2 }
                ]
                
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: modelData.icon
                        width: 20
                        height: 20
                        color: parent.parent.hoveredSlot === modelData.index ? modelData.color : "white"
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
        }
        
        // Drag handler with gravity snap
        DragHandler {
            id: dragHandler
            target: highlightRect
            xAxis.enabled: true
            yAxis.enabled: false
            xAxis.minimum: 0
            xAxis.maximum: track.width - highlightRect.width
            
            onActiveChanged: {
                if (!active) {
                    // Find nearest snap position from CURRENT position
                    var center = highlightRect.x + highlightRect.width / 2
                    var nearestIndex = 0
                    var minDist = Math.abs(center - (root.snapPositions[0] + root.slotWidth / 2))
                    
                    for (var i = 1; i < root.snapPositions.length; i++) {
                        var dist = Math.abs(center - (root.snapPositions[i] + root.slotWidth / 2))
                        if (dist < minDist) {
                            minDist = dist
                            nearestIndex = i
                        }
                    }
                    
                    var newProfile = root.profiles[nearestIndex]
                    
                    // Update internal profile FIRST (for instant visual update)
                    root.internalProfile = newProfile
                    
                    // Animate from current position to target
                    snapAnimation.to = root.snapPositions[nearestIndex]
                    snapAnimation.start()
                    
                    // Then emit signal
                    root.profileChanged(newProfile)
                }
            }
        }
        
        // Gravity effect during drag
        Timer {
            interval: 16 // ~60fps
            running: dragHandler.active
            repeat: true
            
            onTriggered: {
                var center = highlightRect.x + highlightRect.width / 2
                var totalForce = 0
                var gravityThreshold = root.slotWidth * 0.6
                var gravityStrength = 0.12
                
                // Calculate gravity pull from each snap point
                for (var i = 0; i < root.snapPositions.length; i++) {
                    var snapCenter = root.snapPositions[i] + root.slotWidth / 2
                    var distance = Math.abs(center - snapCenter)
                    
                    if (distance < gravityThreshold && distance > 1) {
                        // Gravity force inversely proportional to distance
                        var force = (gravityThreshold - distance) / gravityThreshold
                        force = force * force * gravityStrength // Quadratic falloff
                        
                        if (center > snapCenter) {
                            totalForce -= force * root.slotWidth
                        } else {
                            totalForce += force * root.slotWidth
                        }
                    }
                }
                
                // Apply subtle gravity pull
                if (Math.abs(totalForce) > 0.3) {
                    highlightRect.x += totalForce * 0.08
                    
                    // Clamp to bounds
                    highlightRect.x = Math.max(0, Math.min(track.width - highlightRect.width, highlightRect.x))
                }
            }
        }
        
        // Click handler for direct selection
        TapHandler {
            onTapped: (eventPoint) => {
                var clickX = eventPoint.position.x
                var slotIndex = Math.floor(clickX / root.slotWidth)
                slotIndex = Math.max(0, Math.min(2, slotIndex))
                
                var newProfile = root.profiles[slotIndex]
                root.internalProfile = newProfile
                
                // Animate to new position
                snapAnimation.to = root.snapPositions[slotIndex]
                snapAnimation.start()
                
                root.profileChanged(newProfile)
            }
        }
    }
}
